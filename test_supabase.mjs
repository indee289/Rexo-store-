import { createClient } from '@supabase/supabase-js';
import fs from 'fs';
const env = fs.readFileSync('.env.local', 'utf-8');
let url = '';
let key = '';
env.split('\n').forEach(line => {
  if (line.startsWith('VITE_SUPABASE_URL=')) url = line.split('=')[1].trim();
  if (line.startsWith('VITE_SUPABASE_ANON_KEY=')) key = line.split('=')[1].trim();
});
const supabase = createClient(url, key);

async function test() {
  const { data, error } = await supabase.from('products').insert({
    id: "prod_1234",
    title: "Test",
    productType: "digital",
    category: "AI Prompts",
    shortDescription: "test",
    fullDescription: "test",
    coverImage: "test",
    galleryImages: [],
    price: 10,
    stock: -1,
    tags: [],
    featuresIncluded: [],
    requirements: [],
    status: "active",
    publishDate: new Date().toISOString(),
    isFree: false,
    isPaid: true
  });
  console.log('Error:', error);
  console.log('Data:', data);
}
test();
